from galaxy.jobs import JobDestination
import os
import sys
import json
import cStringIO
import logging

log = logging.getLogger( __name__ )


def dump(obj, nested_level=0, output=sys.stdout):
    spacing = '   '
    if type(obj) == dict:
        print >> output, '%s{' % ((nested_level) * spacing)
        for k, v in obj.items():
            if hasattr(v, '__iter__'):
                print >> output, '%s%s:' % ((nested_level + 1) * spacing, k)
                dump(v, nested_level + 1, output)
            else:
                print >> output, '%s%s: %s' % ((nested_level + 1) * spacing, k, v)
        print >> output, '%s}' % (nested_level * spacing)
    elif type(obj) == list:
        print >> output, '%s[' % ((nested_level) * spacing)
        for v in obj:
            if hasattr(v, '__iter__'):
                dump(v, nested_level + 1, output)
            else:
                print >> output, '%s%s' % ((nested_level + 1) * spacing, v)
        print >> output, '%s]' % ((nested_level) * spacing)
    else:
        print >> output, '%s%s' % (nested_level * spacing, obj)


def dynamic_slurm_cluster_gatk(job, tool_id):
    # Allocate extra time
    inp_data = dict( [ ( da.name, da.dataset ) for da in job.input_datasets ] )
    inp_data.update( [ ( da.name, da.dataset ) for da in job.input_library_datasets ] )
    inp_data.update( [ ( da.name, json.loads(da.value) ) for da in job.parameters ] )
    out = cStringIO.StringIO()
    dump(inp_data, 1, out)
    log.debug(out.getvalue())
    
    nativeSpecs = '--nodes=1 --ntasks=1'
    
    # runner doesn't allow to specify --cpus-per-task
    # thus the mem calculation gets messy with more than 1 node
    # --> translate nt ==> nodes, nct ==> ntasks
    
    if 'cond_threads' not in inp_data:
        return JobDestination(runner="slurm")
    
    if inp_data['cond_threads']['cond_threads_enabled'] == "True":
        nNodes = int(inp_data['cond_threads']['nt'])
        nCPU   = int(inp_data['cond_threads']['nct'])
        nMEM   = int(inp_data['cond_threads']['mem'])
        if nMEM > 0:
            nativeSpecs = '--nodes=%d --ntasks=%d --mem=%d' % (nNodes, nCPU*nNodes, nMEM)
        else:
            nativeSpecs = '--nodes=%d --ntasks=%d' % (nNodes, nCPU*nNodes)
        
    return JobDestination(runner="slurm", params={"nativeSpecification": nativeSpecs})

